class Room < ActiveRecord::Base

  def self.join(room_id, user_id)

    err, users = add_user(room_id, user_id)
    return [err, users, nil] if err

    # Push message
    Pusher.join(room_id, user_id, username)

    group_info = nil
    if users.length == 3
      # create group and push start msg to group members
      g = Group.create(room_id: room_id, 
                       round_id: 0, 
                       moneys: [0, 0, 0],
                       users_id: [users[0]['user_id'], users[1]['user_id'], users[2]['user_id']],
                       betray_penalty: Group.generate_penalty())
      group_info = {}
      group_info[:id] = g.id
      group_info[:users] = []

      users.each do |u|
        user = User.find(u['user_id'])
        user.group_id = g.id
        user.round_id = 0
        user.save!
        group_info[:users] << {:id => user.id, :username => user.username }
      end

      group_info[:round_id] = g.round_id
      group_info[:moneys] = g.moneys
      group_info[:betray_penalty] = g.betray_penalty

      Pusher.start(room_id, user_id, g.id, group_info)
    end

    [nil, users, group_info]
  end

  def self.leave(room_id, user_id)

  	err, users = delete_user(room_id, user_id)
  	return [err, users] if err

    # Push message
    Pusher.leave(room_id, user_id)

    [nil, users]
  end

  private
    def self.add_user(room_id, user_id)
      self.transaction do
        r = Room.find(room_id)
        return ['fullRoom', nil] if r.user_id.length == 3

        r.users_id << user_id
        r.users_id = r.users_id.to_set.to_a
        r.save!
        users = []
        r.users_id do |u_id|
          users << User.find(u_id).username
        end
        return [nil, users]
      end
    end

    def self.delete_user(room_id, user_id)
      self.transaction do
        r = Room.find(room_id)
        return ['emptyRoom', nil] if r.user_id.length == 0
        
        new_users = r.users_id.select {|u| u != user_id}
        
        # delete a user don't belong here
        return ['nullUser', new_users] if new_users == r.users_id

        r.users_id = new_users
        r.save!

        u = User.find(user_id)
        u.room_id = nil
        u.save!

      end

    end


end