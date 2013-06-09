class AddLocalPathToMovie < ActiveRecord::Migration
  def change
    add_column :movies, :local_path, :string
  end
end
