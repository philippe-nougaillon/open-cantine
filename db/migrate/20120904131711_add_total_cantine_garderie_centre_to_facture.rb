class AddTotalCantineGarderieCentreToFacture < ActiveRecord::Migration
  def change
		add_column :factures, :total_cantine, :decimal , :precision => 8, :scale => 2
		add_column :factures, :total_garderie, :decimal , :precision => 8, :scale => 2
		add_column :factures, :total_centre, :decimal , :precision => 8, :scale => 2
		add_column :factures, :total_etude, :decimal , :precision => 8, :scale => 2
  end
end
