class Prestation < ActiveRecord::Base

  attr_protected :id

  belongs_to :enfant
  has_many :familles, :through => :enfant
 
  validates_presence_of :date, :message => "Date manquante !"
  validates_uniqueness_of :enfant_id, :scope => [:date], :message => "&Prestation en doublon de date"

  scope :afacturer,   :conditions => "facture_id is null", :order => 'date'
  scope :facturees,   :conditions => "facture_id is not null", :order => 'date'

  scope :_repas,       :conditions => "repas = '1'"
  scope :_garderieAM,  :conditions => "garderieAM = '1'"
  scope :_garderiePM,  :conditions => "garderiePM = '1'"
  scope :_centreAM,    :conditions => "centreAM = '1'"
  scope :_centrePM,    :conditions => "centrePM = '1'"
  scope :_etude,	   :conditions => "etude = '1'"

  def self.search(search, classe, mairie, sort, periode)
    @prestations = Prestation.joins(:enfant).joins(:familles).where("familles.mairie_id = ?", mairie)
    unless classe.blank?
      @prestations = @prestations.where("enfants.classe = ?",classe)
    end

    case periode
    when "jour"
      @prestations = @prestations.where('prestations.date like ?', search.to_date.to_s(:en)) 
    when "semaine"
      datedebut = search.to_date
      datefin = search.to_date + 1.week
      @prestations = @prestations.where('(prestations.date between ? AND ? )',datedebut, datefin)
    when "mois"
      datedebut = search.to_date.at_beginning_of_month
      datefin = search.to_date.at_end_of_month
      @prestations = @prestations.where('(prestations.date between ? AND ? )',datedebut, datefin)
    end  
    @prestations.order(sort)
  end  

  
   def calc_repas
     
     # calcul que le cout repas, permet le détail repas / Centre+Garderie
     tarif = self.tarif
     total = 0.00
     total = tarif.RepasP if self.repas == '1'

     return total
   end

   def calc_credit
      return 0
   end

end
