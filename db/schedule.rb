class Schedule < ActiveRecord::Base
  belongs_to :user

  def self.handle_subscription(mode = :create, message)
    return false unless [:create, :destroy].include? mode
    return false unless message.is_a? Telegram::Bot::Types::Message

    return create_subscription message if mode == :create
    return destroy_subscription message if mode == :destroy
  end

  def self.create_subscription(message)
    s = Schedule.find_by_user_id_and_chat_id message.from.id, message.chat.id
    if s
      return false
    end
    from = message.from
    user_id = if from then from.id else -1 end
    s = Schedule.create(
      user_id: user_id,
      chat_id: message.chat.id,
      cronwhen: '',
      command: ''
    )
    true
  end

  def self.destroy_subscription(message)
    from = message.from
    user_id = if from then from.id else -1 end
    s = Schedule.find_by_user_id_and_chat_id user_id, message.chat.id
    unless s
      return false
    end
    s.delete
    true
  end

end
