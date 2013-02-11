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

  def self.search(search, classe, mairie, sort, order, toutlemois)
     if toutlemois
         datedebut = search.to_date.at_beginning_of_month
         datefin = search.to_date.at_end_of_month
         conditions = ['(date between ? AND ? ) AND (classe = ? ) AND mairie_id = ? ',
                          datedebut, datefin, classe, mairie]
     else
         conditions = ['prestations.date like ? AND enfants.classe = ? AND mairie_id = ? AND prestations.facture_id is null',
                          "%#{search.to_date.to_s(:en)}%", classe, mairie]
     end
     Prestation.find(:all, :conditions => conditions, :order => sort + " " + order, :joins => :enfants, :joins => :familles)
  end

  def tarif
      # RETOURNE LE TARIF A APPLIQUER, POUR CETTE PRESTATION ET POUR CET ENFANT

      enfant = Enfant.find(self.enfant_id)	
      mairie = Ville.find(enfant.famille.mairie_id)

      #charge le module Facturation de cette mairie
      load "facturation_modules/#{mairie.FacturationModuleName}"

      #retourne le tarif
      return Facturation.best_tarif(enfant)
  end

  def calc_prestation(prestations_normales)

      #tarif = self.tarif

      #charge le module facturation de cette mairie
      #@mairie = Ville.find(Famille.find(Enfant.find(self.enfant_id).famille_id).mairie_id)

      jour  = self.date.day.to_s

      enfant = Enfant.find(self.enfant_id)
      mairie = Ville.find(enfant.famille.mairie_id)

      load "facturation_modules/#{mairie.FacturationModuleName}"

      prestations_normales = Facturation.calc_prestation(prestations_normales, self, Facturation.best_tarif(enfant), jour)

      return prestations_normales
  end

  def tarif_majoration
       # RETOURNE LE TARIF A APPLIQUER, POUR CETTE PRESTATION ET POUR CET ENFANT
      @mairie = Ville.find(Famille.find(Enfant.find(self.enfant_id).famille_id).mairie_id)

      #charge le module facturation de cette mairie
      load "facturation_modules/#{Ville.find(@mairie).FacturationModuleName}"
      tarif_id = Facturation.tarif_majore(Enfant.find(self.enfant_id))

      #retourne le tarif
      return Tarif.find(:first, :conditions => ['mairie_id = ? AND type_id = ? ', @mairie.id, tarif_id])
  end
  
  def calc_majoration(prestations_majorees)

      tarif_majoration = self.tarif_majoration
      tarif = self.tarif
      jour = self.date.day.to_s

      #charge le module facturation de cette mairie
      @mairie = Ville.find(Famille.find(Enfant.find(self.enfant_id).famille_id).mairie_id)
      load "facturation_modules/#{Ville.find(@mairie).FacturationModuleName}"

      prestations_majorees = Facturation.calc_majoration(prestations_majorees, self, tarif, tarif_majoration, jour)

      return prestations_majorees
   end

  def calc_annulation(prestations_annulees)

      tarif = self.tarif
      jour = self.date.day.to_s

      #charge le module facturation de cette mairie
      @mairie = Ville.find(Famille.find(Enfant.find(self.enfant_id).famille_id).mairie_id)
      load "facturation_modules/#{Ville.find(@mairie).FacturationModuleName}"

      prestations_annulees = Facturation.calc_annulation(prestations_annulees, self, tarif, jour)

      return prestations_annulees
   end

  def calc_annulation_maladie(prestations_annulees_maladie)

      tarif = self.tarif
      jour = self.date.day.to_s

      #charge le module facturation de cette mairie
      @mairie = Ville.find(Famille.find(Enfant.find(self.enfant_id).famille_id).mairie_id)
      load "facturation_modules/#{Ville.find(@mairie).FacturationModuleName}"

      prestations_annulees_maladie = Facturation.calc_annulation_maladie(prestations_annulees_maladie, self, tarif, jour)

      return prestations_annulees_maladie
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
