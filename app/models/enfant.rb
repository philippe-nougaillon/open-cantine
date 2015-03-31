require 'concerns/logmodule.rb'

class Enfant < ActiveRecord::Base
  include LogModule
  
  attr_protected :id

  belongs_to :famille
  has_many   :prestations, :dependent => :destroy

  validates_presence_of :prenom,        :message => "manquant"
  validates_presence_of :famille_id,    :message => "manquante"
  validates_presence_of :nomfamille,    :message => "manquant"
  validates_presence_of :classe,        :message => "manquante"
  validates_length_of   :dateNaissance, :is => 10 , :message => " > Entrez une date comme 01/01/1999"
 
  before_save :uppercase_fields

  def uppercase_fields
    self.prenom.upcase!
  end

  def self.search(search, page, classe, mairie,  sort)
  	@order_by = (sort.blank?) ? "nom, prenom" : sort
  	if classe and !classe.blank? 
  		conditions	= ['nomfamille like ? AND classe = ? AND mairie_id = ?', "%#{search}%", classe, mairie]
  	else
  		conditions	= ['nomfamille like ? AND mairie_id = ?', "%#{search}%", mairie]
  	end
  	paginate :per_page => 10, :page => page, :conditions => conditions, :joins => :famille, :order => @order_by
  end

  def r
     @prestations = Prestation.find_all_by_enfant_id(self.id)
     for p in @prestations
       p.calc_debit
       p.save
     end
  end

end
