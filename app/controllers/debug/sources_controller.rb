class Debug::SourcesController < ActionController::Base
  SOURCE_PATTERNS = %w[ app/**/*.rb app/**/*.erb app/**/*.js app/**/*.css lib/**/*.rb config/routes.rb ].freeze

  def show
    return head :not_found unless Rails.env.development?

    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Content-Type-Options"] = "nosniff"

    if params[:path].present?
      if source_files.include?(params[:path])
        render plain: Rails.root.join(params[:path]).read, content_type: "text/plain"
      else
        head :not_found
      end
    else
      render json: { files: source_files }
    end
  end

  private
    def source_files
      Dir.glob(SOURCE_PATTERNS, base: Rails.root).sort.select do |relative_path|
        path = Rails.root.join(relative_path)
        path.file? && path.realpath == path
      end
    end
end
