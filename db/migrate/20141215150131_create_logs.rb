class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.datetime :date
      t.string :qui
      t.string :action
      t.string :quoi
      t.string :msg

      t.timestamps
    end
  end
end
