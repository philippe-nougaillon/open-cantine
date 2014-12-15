class AddLogDateDefaultValue < ActiveRecord::Migration
  def up
  	remove_column :logs, :date 
  end

  def down
  end
end
