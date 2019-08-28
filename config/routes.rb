Rails.application.routes.draw do
  namespace "api" do
    namespace "images" do
      get "juicebox"
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
