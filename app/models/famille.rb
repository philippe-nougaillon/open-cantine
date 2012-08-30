class Famille < ActiveRecord::Base

  attr_protected :id

  has_many :enfants, :dependent => :destroy
  has_many :prestations, :through => :enfants
  has_many :paiements
  has_many :factures

  
  validates_presence_of   :nom, :message => " manquant !"
  #validates_uniqueness_of :nom, :scope => [:nom, :adresse], :message => "Cette famille existe déjà dans la base !"

  before_save :uppercase_fields

  def uppercase_fields
    self.ville.upcase!
    self[:nom].upcase!
  end


  def familles_by_ville(mairie_id)
  	Famille_find_all_by_mairie_id(mairie_id)
  end
 
  def self.search(nom, page, mairie_id, sort)
	@order_by = (sort.blank?) ? "nom" : sort	
 	paginate :per_page => 18,
          :page => page,
          :conditions => ['nom like ? AND mairie_id = ?', "%#{nom}%", mairie_id],
          :order => @order_by
  end

  def nbrenfants
     return Enfant.count(:conditions => ['famille_id = ?', id])
  end

  def a_facturer
      total = 0.0
      enfants = Enfant.find_all_by_famille_id(self.id)
      if enfants.size > 0
        for enfant in enfants
          prestations = Prestation.find(:all, :conditions => ['enfant_id = ? AND facture_id is null ', enfant.id])
          if prestations.size > 0
            for prestation in prestations
              total = total + prestation.calc_debit
            end
          end
        end
      end
      return (total)

  end

end
