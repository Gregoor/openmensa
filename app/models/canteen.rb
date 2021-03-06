require 'open-uri'
require 'rexml/document'

class Canteen < ActiveRecord::Base
  belongs_to :user
  has_many :days
  has_many :meals, through: :days
  has_many :messages

  scope :active, -> { where(active: true) }

  validates :address, :city, :name, :user_id, presence: true

  geocoded_by :address
  after_validation :geocode, if: :geocode?

  def geocode?
    return false unless Rails.env.production? || Rails.env.development?
    !(address.blank? || (!latitude.blank? && !longitude.blank?)) || address_changed?
  end

  def fetch_hour_default
    self[:fetch_hour_default] || 8
  end

  def fetch(options = {})
    OpenMensa::Updater.new(self, options).update
  end

  def fetch_if_needed
    return false unless ((fetch_hour || fetch_hour_default)..14).include? Time.zone.now.hour
    fetch today: !last_fetched_at.nil? && last_fetched_at.to_date == Time.zone.now.to_date
  end

  def fetch_state
    if !active?
      :out_of_order
    elsif last_fetched_at.nil?
      :no_fetch_ever
    elsif last_fetched_at > Time.zone.now - 1.day
      :fetch_up_to_date
    else
      :fetch_needed
    end
  end
end
