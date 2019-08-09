# encoding: utf-8
require 'concerns/logmodule.rb'

class Prestation < ApplicationRecord
  include LogModule

  belongs_to :enfant
  has_many :familles, :through => :enfant
 
  validates_presence_of :date, :message => "Date manquante !"
  validates_uniqueness_of :enfant_id, :scope => [:date], :message => "&Prestation en doublon de date"

  scope :afacturer,   -> { where("facture_id is null").order(:date) }
  scope :facturees,   -> { where("facture_id is not null").order(:date) }
  scope :_repas,      -> { where(repas:'1') }
  scope :_garderieAM, -> { where(garderieAM:'1') }
  scope :_garderiePM, -> { where(garderiePM:'1') }
  scope :_centreAM,   -> { where(centreAM:'1') }
  scope :_centrePM,   -> { where(centrePM:'1') }
  scope :_etude,	    -> { where(etude:'1') }

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

   def self.duree_garderie
      [
        ['15min', 5], ['30min', 6], ['45min', 7], ['1h', 8], ['1h15min', 9], ['1h30min', 10], ['1h45min', 11], ['2h', 12], ['2h15', 13], ['2h30', 14]
      ]
   end  

   def self.duree_garderie_matin
      [
        ['Arrivée 6h30', 12],['Arrivée 6h45', 11], ['Arrivée 7h', 10],['Arrivée 7h15', 9],['Arrivée 7h30', 8], ['Arrivée 7h45', 7],['Arrivée 8h', 6],['Arrivée 8h15', 5]
      ]
   end 

   def self.duree_garderie_soir
      [
        ['Départ 16h15', 5],['Départ 16h30', 6],['Départ 16h45', 7],['Départ 17h', 8],['Départ 17h15', 9],['Départ 17h30', 10],['Départ 17h45', 11],['Départ 18h', 12],['Départ 18h15', 13],['Départ 18h30', 14]
      ]
   end
        
end
