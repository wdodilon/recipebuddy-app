# frozen_string_literal: true

require 'roda'
require 'slim'
require 'slim/include'

module RecipeBuddy
  # Web App
  class App < Roda
    plugin :render, engine: 'slim', views: 'presentation/views'
    plugin :assets, css: 'style.css', path: 'presentation/assets'
    plugin :flash

    use Rack::Session::Cookie, secret: config.SESSION_SECRET

    route do |routing|
      routing.assets

      # GET / request
      routing.root do
        recipes_json = ApiGateway.new.best_recipes
        best_recipes = RecipeBuddy::RecipesRepresenter.new(OpenStruct.new)
                                                      .from_json recipes_json

        recipes = Views::AllRecipes.new(best_recipes)
        if recipes.none?
          flash.now[:notice] = 'Add a Facebook public page to get started'
        end
        view 'home', locals: { recipes: recipes }
      end

      routing.on 'page' do
        # routing.is String do |pagename|
        #   # GET /api/v0.1/page/:pagename request
        #   page_json = ApiGateway.new.get_page(pagename)
        #   page = RecipeBuddy::PageRepresenter.new(OpenStruct.new)
        #                                      .from_json page_json
        #
        #   view_page = Views::Page.new(page)
        #   view 'page', locals: { page: view_page }
        # end

        routing.post do
          create_request = Forms::FacebookPageURLValidator.call(routing.params)
          result = AddPage.new.call(create_request)
          # page = RecipeBuddy::PageRepresenter.new(OpenStruct.new)
          #                                    .from_json result.value[:response]

          if result.success?
            flash[:notice] = 'New Facebook Page added!'
          else
            flash[:error] = result.value
          end
          routing.redirect '/'
        end
      end
    end
  end
end
