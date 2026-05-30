require "test_helper"

class Dashboard::ProofOfWorkNextActionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "proof@example.com",
      password: "password123",
      username: "proofuser",
      account_status: :active
    )
  end

  test "returns create project action when user has no projects" do
    action = Dashboard::ProofOfWorkNextAction.new(@user)

    assert_equal :no_projects, action.state
    assert_equal "Create your first project story", action.cta_label
    assert_equal "/projects/new", action.cta_path
  end

  test "returns add story context action when projects have no meaningful story content" do
    project = create_project(title: "Weak Draft", status: :draft, updated_at: 2.hours.ago)
    newer_project = create_project(title: "Newer Weak Draft", status: :draft, updated_at: 1.hour.ago)

    action = Dashboard::ProofOfWorkNextAction.new(@user)

    assert_equal :add_story_context, action.state
    assert_equal "Add story context", action.cta_label
    assert_equal "/projects/#{newer_project.id}/edit#story-builder", action.cta_path
    assert_not_equal "/projects/#{project.id}/edit", action.cta_path
  end

  test "returns publish action for newest draft meaningful project" do
    create_project(
      title: "Older Draft Story",
      status: :draft,
      story: meaningful_story,
      updated_at: 2.hours.ago
    )
    newer_project = create_project(
      title: "Newer Draft Story",
      status: :draft,
      story: meaningful_story,
      updated_at: 1.hour.ago
    )

    action = Dashboard::ProofOfWorkNextAction.new(@user)

    assert_equal :publish_project_story, action.state
    assert_equal "Publish your project story", action.cta_label
    assert_equal "/projects/#{newer_project.id}/edit#story-builder", action.cta_path
  end

  test "returns improve action when published projects have weak story content" do
    project = create_project(title: "Published Weak", status: :published, updated_at: 1.hour.ago)

    action = Dashboard::ProofOfWorkNextAction.new(@user)

    assert_equal :improve_published_story, action.state
    assert_equal "Improve your published story", action.cta_label
    assert_equal "/projects/#{project.id}/edit#story-builder", action.cta_path
  end

  test "returns share story action for one published meaningful story" do
    project = create_project(title: "Published Story", status: :published, story: meaningful_story)

    action = Dashboard::ProofOfWorkNextAction.new(@user)

    assert_equal :share_project_story, action.state
    assert_equal "Share your project story", action.cta_label
    assert_equal "/explore/#{project.id}", action.cta_path
  end

  test "returns share profile action for multiple published meaningful stories" do
    create_project(title: "Older Published Story", status: :published, story: meaningful_story, updated_at: 2.hours.ago)
    newer_project = create_project(title: "Newer Published Story", status: :published, story: meaningful_story, updated_at: 1.hour.ago)

    action = Dashboard::ProofOfWorkNextAction.new(@user)

    assert_equal :share_proof_of_work_profile, action.state
    assert_equal "Share your proof-of-work profile", action.cta_label
    assert_equal "/#{@user.friendly_id}", action.cta_path
    assert_equal "Generate resume bullets", action.secondary_cta_label
    assert_equal "/projects/#{newer_project.id}/edit#resume-bullets", action.secondary_cta_path
  end

  test "returns generate resume bullets secondary action for one published meaningful story" do
    project = create_project(title: "Published Story", status: :published, story: meaningful_story)

    action = Dashboard::ProofOfWorkNextAction.new(@user)

    assert_equal :share_project_story, action.state
    assert_equal "Generate resume bullets", action.secondary_cta_label
    assert_equal "/projects/#{project.id}/edit#resume-bullets", action.secondary_cta_path
  end

  private

  def create_project(title:, status:, story: {}, updated_at: Time.current)
    project = @user.projects.create!(
      title: title,
      description: "#{title} description",
      technologies_used: [ "Rails" ],
      status: status,
      project_story: story
    )
    project.update_column(:updated_at, updated_at)
    project
  end

  def meaningful_story
    {
      overview: "Built a proof-of-work flow",
      problem: "Projects are hard to explain"
    }
  end
end
