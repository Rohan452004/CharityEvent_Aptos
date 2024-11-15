module CharityEvent::CharityRewards {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::error;

    /// Error codes
    const EINVALID_REWARD_AMOUNT: u64 = 1;
    const EINVALID_EVENT_STATUS: u64 = 2;

    /// Struct to store charity event details and reward pool
    struct CharityEvent has store, key {
        reward_pool: u64,      // Total tokens available for rewards
        is_active: bool,       // Event status
        participants: u64,     // Number of participants
    }

    /// Initialize a new charity event with reward pool
    public fun create_event(
        organizer: &signer, 
        initial_reward_pool: u64
    ) {
        let event = CharityEvent {
            reward_pool: initial_reward_pool,
            is_active: true,
            participants: 0,
        };
        
        // Transfer initial reward pool from organizer
        let tokens = coin::withdraw<AptosCoin>(organizer, initial_reward_pool);
        coin::deposit(signer::address_of(organizer), tokens);
        
        move_to(organizer, event);
    }

    /// Distribute rewards to participants of charity event
    public fun distribute_reward(
        organizer: &signer,
        participant: address,
        reward_amount: u64
    ) acquires CharityEvent {
        let event = borrow_global_mut<CharityEvent>(signer::address_of(organizer));
        
        assert!(event.is_active, error::invalid_state(EINVALID_EVENT_STATUS));
        assert!(
            reward_amount <= event.reward_pool, 
            error::invalid_argument(EINVALID_REWARD_AMOUNT)
        );

        // Transfer reward to participant
        let reward = coin::withdraw<AptosCoin>(organizer, reward_amount);
        coin::deposit(participant, reward);

        // Update event stats
        event.reward_pool = event.reward_pool - reward_amount;
        event.participants = event.participants + 1;
    }
}