require 'concerns/logmodule.rb'

class Facture < ActiveRecord::Base
  include LogModule

  attr_protected :id

  belongs_to :ville, foreign_key:"mairie_id"
  belongs_to :famille

  has_many :facture_lignes, :dependent => :destroy

  def self.search(search, page, mairie_id, sort, famille_id)
    if famille_id
      conditions = ['ref like ? AND factures.mairie_id = ? AND famille_id = ?', "%#{search}%", mairie_id, famille_id]
    else
      conditions = ['ref like ? AND factures.mairie_id = ?', "%#{search}%", mairie_id]
    end
	  @order_by = (sort.blank?) ? "id DESC" : sort	
    paginate :per_page => 18, :page => page, :conditions => conditions, :joins => :famille, :order => @order_by
  end
  
end
