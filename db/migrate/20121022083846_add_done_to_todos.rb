class AddDoneToTodos < ActiveRecord::Migration
  def change
	add_column :todos, :done, :boolean, :default => 0
	add_column :todos, :mairie_id, :integer
	add_column :todos, :note, :string
  end
end
