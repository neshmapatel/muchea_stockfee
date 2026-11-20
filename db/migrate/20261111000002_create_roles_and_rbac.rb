class CreateRolesAndRbac < ActiveRecord::Migration[8.1]
  class MigrationRole < ApplicationRecord
    self.table_name = "roles"
  end

  class MigrationAdminUser < ApplicationRecord
    self.table_name = "admin_users"
  end

  def up
    create_table :roles do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.text :permissions, null: false, default: "[]"
      t.boolean :is_super_admin, null: false, default: false
      t.boolean :system_role, null: false, default: false
      t.integer :display_order, null: false, default: 0

      t.timestamps
    end
    add_index :roles, :slug, unique: true
    add_index :roles, :is_super_admin

    add_reference :admin_users, :role, null: true, foreign_key: true
    add_column :admin_users, :active, :boolean, null: false, default: true
    add_column :admin_users, :phone, :string
    add_column :admin_users, :created_by_id, :integer
    add_index :admin_users, :active
    add_index :admin_users, :created_by_id

    add_reference :inventory_logs, :admin_user, null: true, foreign_key: { on_delete: :nullify }

    # Backfill existing AdminUser records so role_id is never null
    MigrationRole.reset_column_information
    MigrationAdminUser.reset_column_information

    if MigrationAdminUser.exists?
      super_role = MigrationRole.find_or_create_by!(slug: "super_admin") do |r|
        r.name = "Super Admin"
        r.description = "Full unrestricted system control including staff, roles, super admins, and warehouse operations."
        r.permissions = "[]"
        r.is_super_admin = true
        r.system_role = true
        r.display_order = 1
      end

      MigrationAdminUser.find_each do |user|
        user.update_columns(role_id: super_role.id, active: true)
      end
    end

    change_column_null :admin_users, :role_id, false
    remove_column :admin_users, :role, :string
  end

  def down
    add_column :admin_users, :role, :string, default: "admin", null: false

    MigrationRole.reset_column_information
    MigrationAdminUser.reset_column_information
    role_map = MigrationRole.pluck(:id, :slug).to_h

    MigrationAdminUser.find_each do |user|
      user.update_columns(role: role_map[user.role_id] || "admin")
    end

    remove_reference :inventory_logs, :admin_user, foreign_key: true
    remove_index :admin_users, :created_by_id
    remove_index :admin_users, :active
    remove_column :admin_users, :created_by_id
    remove_column :admin_users, :phone
    remove_column :admin_users, :active
    remove_reference :admin_users, :role, foreign_key: true
    drop_table :roles
  end
end

