class SitemapsController < ApplicationController
  def index
    @categories = Category.ordered
    @products = Product.active
    respond_to do |format|
      format.xml
    end
  end
end

