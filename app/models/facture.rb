require 'concerns/logmodule.rb'

class Facture < ActiveRecord::Base
  include LogModule

  belongs_to :ville, foreign_key:"mairie_id"
  belongs_to :famille

  has_many :facture_lignes, :dependent => :destroy

  validates_presence_of :famille_id, :mairie_id, :date, :montant, :ref

  def self.search(search, page, mairie_id, sort, famille_id)
    if famille_id
      conditions = ['ref like ? AND factures.mairie_id = ? AND famille_id = ?', "%#{search}%", mairie_id, famille_id]
    else
      conditions = ['(familles.nom like ? OR ref like ?) AND factures.mairie_id = ?', "%#{search}%", "%#{search}%", mairie_id]
    end
	  @order_by = (sort.blank?) ? "id DESC" : sort	
    paginate(per_page:20, page:page).where(conditions).joins(:famille).order(@order_by)
  end
  
end
