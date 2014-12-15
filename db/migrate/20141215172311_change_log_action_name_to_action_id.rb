class ChangeLogActionNameToActionId < ActiveRecord::Migration
  def up
  	remove_column :logs, :action 
  	add_column :logs, :action_id, :integer
  end

  def down
  end
end
