class Sessions::Event::ChatSessionStart < Sessions::Event::ChatBase

  def run

    # find first in waiting list
    chat_session = Chat::Session.where(state: 'waiting').order('created_at ASC').first
    if !chat_session
      return {
        event: 'chat_session_start',
        data: {
          state: 'failed',
          message: 'No session available.',
        },
      }
    end
    chat_session.user_id = @session['id']
    chat_session.state = 'running'
    chat_session.preferences[:participants] = chat_session.add_recipient(@client_id)
    chat_session.save

    # send chat_session_init to client
    chat_user = User.find(chat_session.user_id)
    url = nil
    if chat_user.image && chat_user.image != 'none'
      url = "/api/v1/users/image/#{chat_user.image}"
    end
    user = {
      name: chat_user.fullname,
      avatar: url,
    }
    data = {
      event: 'chat_session_start',
      data: {
        state: 'ok',
        agent: user,
        session_id: chat_session.session_id,
      },
    }
    chat_session.send_to_recipients(data)

    # send position update to other waiting sessions
    broadcast_customer_state_update

    # send state update to agents
    broadcast_agent_state_update

    nil
  end
end
