class AddLogUserId < ActiveRecord::Migration
  def up
  	add_column :logs, :user_id, :integer
  	add_index :logs, :user_id
  end

  def down
  end
end
