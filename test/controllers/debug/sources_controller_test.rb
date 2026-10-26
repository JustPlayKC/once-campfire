require "test_helper"

class Debug::SourcesControllerTest < ActionController::TestCase
  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { get "debug/source", to: "debug/sources#show" }
  end

  test "source is unavailable outside development" do
    get :show, params: { path: "config/routes.rb" }

    assert_response :not_found
  end

  test "lists allowed source files in development" do
    Rails.env.stubs(:development?).returns(true)

    get :show

    assert_response :success
    files = response.parsed_body.fetch("files")
    assert_includes files, "app/controllers/application_controller.rb"
    assert_includes files, "config/routes.rb"
    assert_not_includes files, "config/credentials.yml.enc"
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "returns source as plain text" do
    Rails.env.stubs(:development?).returns(true)

    get :show, params: { path: "app/controllers/application_controller.rb" }

    assert_response :success
    assert_equal Rails.root.join("app/controllers/application_controller.rb").read, response.body
    assert_equal "text/plain", response.media_type
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "rejects traversal, absolute paths, secrets, and missing files" do
    Rails.env.stubs(:development?).returns(true)

    %w[ ../Gemfile /etc/passwd app/../config/master.key config/master.key .env storage/db/development.sqlite3 app/missing.rb ].each do |path|
      get :show, params: { path: path }

      assert_response :not_found
    end
  end

  test "does not expose symlinks as source files" do
    Rails.env.stubs(:development?).returns(true)
    path = Rails.root.join("app/debug_source_test.rb")
    File.symlink(Rails.root.join("Gemfile"), path)

    get :show, params: { path: "app/debug_source_test.rb" }

    assert_response :not_found
  ensure
    path&.unlink if path&.symlink?
  end
end
