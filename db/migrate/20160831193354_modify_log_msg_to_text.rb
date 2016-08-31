class ModifyLogMsgToText < ActiveRecord::Migration
  def change
  	change_column :logs, :msg, :text
  end
end
