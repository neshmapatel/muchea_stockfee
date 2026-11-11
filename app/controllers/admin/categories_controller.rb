module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: [:edit, :update, :destroy]

    def index
      @categories = Category.includes(:products).order(:department, :display_order, :name)
    end

    def new
      @category = Category.new(department: "Stockfeed & Animal Nutrition")
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path, notice: "Category '#{@category.name}' created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category '#{@category.name}' updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.products.any?
        redirect_to admin_categories_path, alert: "Cannot delete category '#{@category.name}' because it contains #{@category.products.count} products."
      else
        @category.destroy
        redirect_to admin_categories_path, notice: "Category removed."
      end
    end

    private

    def set_category
      @category = Category.find_by(slug: params[:id]) || Category.find_by(id: params[:id])
      redirect_to admin_categories_path, alert: "Category not found." unless @category
    end

    def category_params
      params.require(:category).permit(:name, :slug, :department, :description, :icon, :display_order)
    end
  end
end
