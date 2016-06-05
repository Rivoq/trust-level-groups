after_initialize do

  class ::Jobs::TrustLevelGroupsMembership < Jobs::Scheduled

    every 1.minute

    def execute(args)
      groups = Group.where("automatic_membership_email_domains ~* 'trustlevel[0-4].com'")
      groups.each do |group|

        puts "Processing group:"
        puts group.inspect

        # find 'special' domains, that we use to denote members' trust level
        # - trustlevel0.com
        # - trustlevel1.com
        # - trustlevel2.com
        # - trustlevel3.com
        # - trustlevel4.com
        group.automatic_membership_email_domains =~ /trustlevel(\d+)/
        min_trust_level = $1
        puts "min trust level: #{min_trust_level}"
        eligible_user_ids = User.where('id > 0 AND trust_level = ?', min_trust_level).
                                 pluck(:id).to_a
        current_user_ids = GroupUser.where(group_id: group.id).pluck(:user_id).to_a
        puts "Current user ids: #{current_user_ids}"

        user_ids_to_add = eligible_user_ids - current_user_ids
        user_ids_to_remove = current_user_ids - eligible_user_ids

        puts "user ids to add: #{user_ids_to_add}"
        puts "user ids to remove: #{user_ids_to_remove}"

        user_ids_to_add.each do |user_id|
          puts "Adding user: #{user_id}"
          user = User.find(user_id)
          begin
            group.add(user)
          rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
            # we don't care about this
          end
        end

        user_ids_to_remove.each do |user_id|
          puts "Removing user: #{user_id}"
          user = User.find(user_id)
          group.remove(user)
        end
        
      end
    end
  end

end
