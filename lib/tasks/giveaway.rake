task :create_pending_claims => :environment do
  team = Wcg.get_team
  # For each user we want to calculate a few things in order to process
  # any new comuting time they have accumulated

  # We also want to use an aggregation of all the users to determine the
  # exchange rate for the current XRP payount in relation to WCG points

  User.all.each do |user|
    # Calculate the total number of points the user has accumulated by
    # subtracting the amount of points they had when they registered
    wcg_team_member = team.find_member_by_id(user.member_id)
    if wcg_team_member
      points_earned = wcg_team_member.points

      if points_earned > 0

        # Sum all the claims they have submitted
        # this will be used to determine how many points they should claim
        # during this round of processing of points

        # Subtract the total number of points in their WCG profile from the
        # points they have already submitted for claiming
        points_to_submit = points_earned - user.points_claimed

        if points_to_submit > 0
          # Create a claim for the user representing all the points they have
          # earned but which have not yet been submitted to the ripple service
          # for tabulation. This claim is not yet finished as it still depends
          # on an XRP rate.
          user.claims.create(points: points_to_submit)
        end
      end
    end
  end
end

task :rollover_failed_claims => :environment do
  insufficient_funds_claims = Claim.where(transaction_status: 'tecNO_DST_INSUF_XRP', rolled_over: false)
  insufficient_funds_claims.collect(&:rollover!)
end

task :set_rate_for_claims => :environment do
  # Fetch all the claims that are still pending, meaning they have not
  # been submitted to the system for disbursion

  # Pending claims may not have an exchange rate attached to them
  # since in order to calculate the exchange rate all of claims for the
  # current claim period must be aggregated.
  claims = Claim.needs_rate

  # Once all the claims for the current period have been created the
  # WCGpoints to XRP exchange rate is calculated for this time period
  # Fetch the amount of XRP to be given away in the current claim period

  total_points_to_be_claimed = claims.inject(0.0){|sum,claim| sum + claim.points}
  xrp_per_point = REDIS.get('xrp_to_give_away').to_f / total_points_to_be_claimed


  if ENV['XRP_PER_POINT']
    xrp_per_point = ENV['XRP_PER_POINT'].to_f
    puts "Manually set XRP per point to: #{xrp_per_point}"
  end

  claims.each do |claim|
    # Set the rate previously calculated for each claim as part of the
    # current batch of claims
    claim.rate = xrp_per_point

    # Compute and store the amount of XRP to be disbersed by the processing
    # backend-system
    claim.xrp_disbursed = claim.points * xrp_per_point

    # Save the claim to be submitted for disbursion of XRP to the user
    claim.save
  end
end

task :submit_pending_claims => :environment do
  Claim.unsubmitted.each do |claim|
    claim.enqueue
    claim.transaction_status = 'submitted'
    claim.save
  end
end

task :retry_claims_from_accounts_that_are_now_funded => :environment do
  claims = Claim.where(transaction_status: 'tecNO_DST_INSUF_XRP').select{|c| c.user.funded? }
  claims.collect(&:duplicate_and_retry)
end

namespace :claims do

  task :calculate_rate_and_submit_for_payment => [
    :create_pending_claims,
    :set_rate_for_claims,
    :rollover_failed_claims,
    :submit_pending_claims
  ]

  task process_payment_confirmations: :environment do
    PaymentConfirmationsQueue.process_confirmed_payments
  end

end
