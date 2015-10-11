# encoding: utf-8

class FactureChronosController < ApplicationController

  layout "standard"

  before_filter :check

  def check
    unless FactureChrono.find(:first, :conditions =>  [" id = ? AND mairie_id = ?",params[:id], session[:mairie]])
       redirect_to :controller => 'admin', :action => 'setup'
    end
  end
 
  # GET /facture_chronos/1/edit
  def edit
    @facture_chrono = FactureChrono.find(params[:id])
  end

  # PUT /facture_chronos/1
  # PUT /facture_chronos/1.xml
  def update
    @facture_chrono = FactureChrono.find(params[:id])

    respond_to do |format|
      if @facture_chrono.update_attributes(facture_chrono_params)
        flash[:notice] = 'Prochain N° de facture modifié.'
        format.html { redirect_to(:controller => 'admin', :action => 'setup') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @facture_chrono.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
    def facture_chrono_params
      params.require(:facture_chrono).permit(:mairie_id,:prochain)
    end

end
