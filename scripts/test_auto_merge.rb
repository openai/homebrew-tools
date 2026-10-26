# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

class AutoMergeTest < Minitest::Test
  WORKFLOW = YAML.load_file(File.expand_path("../.github/workflows/auto-merge-goreleaser.yml", __dir__))
  VERIFY = WORKFLOW.fetch("jobs").fetch("verify").fetch("steps").find { |step| step["id"] == "verify" }.fetch("run")

  def setup
    @pr = {
      author: { login: "app/openai-homebrew-releaser" },
      baseRefName: "main", body: "Automated with [GoReleaser]",
      files: [{ path: "Casks/openai.rb", changeType: "MODIFIED" }],
      headRefName: "openai-update", headRefOid: "a" * 40,
      headRepositoryOwner: { login: "openai" },
      isCrossRepository: false, isDraft: false, state: "OPEN",
      statusCheckRollup: [{ __typename: "CheckRun", workflowName: "Validate cask",
                           name: "validate-cask", status: "COMPLETED", conclusion: "SUCCESS" }],
    }
  end

  def test_unrelated_branches_skip_without_requesting_a_merge
    ["dependabot/github_actions/actions/checkout-7.0.1", "codex/security-guidance"].each do |branch|
      assert_result(:skip, branch: branch)
    end
  end

  def test_ordinary_author_with_release_branch_name_skips
    @pr[:author][:login] = "contributor"
    assert_result(:skip)
  end

  def test_all_supported_release_recipes_remain_eligible
    { "openai" => "Casks/openai.rb", "orchard" => "Formula/orchard.rb",
      "softnet" => "Formula/softnet.rb", "tart-guest-agent" => "Formula/tart-guest-agent.rb",
      "tart" => "Formula/tart.rb" }.each do |tool, path|
      @pr[:headRefName] = "#{tool}-1.2.3"
      @pr[:files][0][:path] = path
      assert_result(:merge, branch: @pr[:headRefName], diff: path)
    end
  end

  def test_reusable_openai_branch_is_eligible
    assert_result(:merge)
  end

  def test_other_non_versioned_release_branches_are_rejected
    ["openai-update-extra", "openai-other", "orchard-update", "tart-update"].each do |branch|
      @pr[:headRefName] = branch
      assert_result(:fail, branch: branch)
    end
  end

  def test_release_pr_must_still_match_the_validated_commit
    @pr[:headRefOid] = "b" * 40
    assert_result(:fail)
  end

  def test_release_pr_must_still_have_successful_validation
    @pr[:statusCheckRollup][0][:conclusion] = "FAILURE"
    assert_result(:fail)
  end

  def test_release_pr_must_still_have_only_the_expected_file
    @pr[:files] << { path: "README.md", changeType: "MODIFIED" }
    assert_result(:fail)
  end

  def test_diff_must_still_match_the_expected_file
    assert_result(:fail, diff: "README.md")
  end

  def test_api_failure_does_not_become_a_successful_skip
    assert_result(:fail, api_status: "1")
  end

  def test_missing_pr_context_does_not_request_a_merge
    assert_result(:fail, number: "")
  end

  def test_app_token_job_requires_verified_pr_output
    job = WORKFLOW.fetch("jobs").fetch("automerge")
    assert_equal "verify", job.fetch("needs")
    assert_equal "needs.verify.outputs.pr-number != ''", job.fetch("if")
  end

  def test_merge_waits_for_required_checks_and_uses_the_validated_head
    job = WORKFLOW.fetch("jobs").fetch("automerge")
    assert_equal 20, job.fetch("timeout-minutes")
    steps = job.fetch("steps")
    assert_equal ["Wait for required checks", "Create GoReleaser app token", "Squash merge validated release PR"],
                 steps.map { |entry| entry.fetch("name") }
    wait, _, merge = steps
    assert_equal "${{ github.token }}", wait.fetch("env").fetch("GH_TOKEN")
    assert_equal "read", job.fetch("permissions").fetch("checks")
    assert_equal "read", job.fetch("permissions").fetch("pull-requests")
    [wait, merge].each do |step|
      assert_equal "${{ needs.verify.outputs.pr-number }}", step.fetch("env").fetch("PR_NUMBER")
    end
    assert_equal "${{ github.event.workflow_run.head_sha }}", merge.fetch("env").fetch("VALIDATED_SHA")

    # A failed check, API error, or pending result must never reach the merge.
    [0, 1, 8].each do |check_status|
      Dir.mktmpdir("homebrew-merge-test") do |directory|
        arguments = File.join(directory, "arguments.jsonl")
        env = { "PR_NUMBER" => "123", "REPO" => "example/tap", "VALIDATED_SHA" => "a" * 40,
                "MERGE_ARGUMENTS" => arguments, "CHECK_STATUS" => check_status.to_s, "GH_TOKEN" => "" }
        stub = <<~'BASH'
          gh() {
            ruby -rjson -e 'File.open(ENV.fetch("MERGE_ARGUMENTS"), "a") { |f| f.puts(JSON.generate(ARGV)) }' -- "$@"
            case "$1 $2" in
              "pr checks") return "$CHECK_STATUS" ;;
              "pr merge") return 0 ;;
              *) return 99 ;;
            esac
          }
        BASH
        stdout, stderr, status = Open3.capture3(env, "bash", "-c", stub + wait.fetch("run") + "\n" + merge.fetch("run"))
        assert_equal check_status.zero?, status.success?, "#{stdout}\n#{stderr}"
        expected = [["pr", "checks", "123", "--repo", "example/tap",
                     "--required", "--watch", "--fail-fast", "--interval", "10"]]
        if check_status.zero?
          expected << ["pr", "merge", "123", "--repo", "example/tap", "--squash", "--admin",
                       "--delete-branch", "--match-head-commit", "a" * 40]
        end
        assert_equal expected, File.readlines(arguments).map { |line| JSON.parse(line) }
      end
    end
  end

  private

  def assert_result(expected, branch: "openai-update", diff: "Casks/openai.rb", api_status: "0", number: "123")
    Dir.mktmpdir("homebrew-automerge-test") do |directory|
      fixture = File.join(directory, "pr.json")
      output = File.join(directory, "output")
      File.write(fixture, JSON.generate(@pr))
      File.write(output, "")
      env = { "PR_NUMBER" => number, "REPO" => "example/tap", "VALIDATED_HEAD_BRANCH" => branch,
              "VALIDATED_SHA" => "a" * 40, "GITHUB_OUTPUT" => output, "PR_FIXTURE" => fixture,
              "PR_DIFF" => diff, "API_STATUS" => api_status, "GH_TOKEN" => "" }
      # The workflow runs Bash, so replace its gh command at the process boundary.
      # No GitHub request, app token creation, or merge is allowed by this fixture.
      stub = <<~'BASH'
        gh() {
          case "$1 $2" in
            "pr view") cat "$PR_FIXTURE"; return "$API_STATUS" ;;
            "pr diff") printf '%s\n' "$PR_DIFF" ;;
            *) return 99 ;;
          esac
        }
      BASH
      stdout, stderr, status = Open3.capture3(env, "bash", "-c", stub + VERIFY)
      assert_equal expected != :fail, status.success?, "#{branch}: #{stdout}\n#{stderr}"
      assert_equal(expected == :merge ? "pr-number=123\n" : "", File.read(output))
    end
  end
end
