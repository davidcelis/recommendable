Rails.application.routes.draw do

  mount Recommendable::Engine => "/recommendable"
end
