class AddArchiveToFamille < ActiveRecord::Migration
  def change
  	add_column :familles, :archive, :boolean
  end
end
