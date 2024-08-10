class Import::Buttondown < Import::BaseService
  def field_mapping
    {
      'email': :email,
      'utm_source': :utm_source,
      'utm_medium': :utm_medium,
      'utm_campaign': :utm_campaign,
      'referrer_url': :referrer_url,
      'creation_date': :created_at,
      'subscription_date': :verified_at,
      'notes': :notes,
      'unsubscription_date': :unsubscribed_at
    }
  end

  def determine_status(row)
    if row["unsubscription_date"] && !row["unsubscription_date"].empty?
      :unsubscribed
    elsif row["subscription_date"] && !row["subscription_date"].empty?
      :verified
    else
      :unverified
    end
  end
end
