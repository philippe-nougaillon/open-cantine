class AddPortailToVille < ActiveRecord::Migration
  def change
  	add_column :villes, :portail, :integer, default:0
  	# 0 => pas d'accès
  	# 1 => accès en lecture seul
  	# 2 => accès avec inscriptions
  end
end
