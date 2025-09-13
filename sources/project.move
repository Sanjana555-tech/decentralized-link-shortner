module MyModule::LinkShortener {
    use aptos_framework::signer;
    use std::string::{Self, String};
    use std::table::{Self, Table};

    /// Struct to store the link mapping for each user
    struct LinkRegistry has store, key {
        links: Table<String, String>,  // Maps short_id -> original_url
        counter: u64,                  // Counter for generating unique IDs
    }

    /// Error codes
    const E_LINK_NOT_FOUND: u64 = 1;
    const E_REGISTRY_NOT_FOUND: u64 = 2;

    /// Function to create a short link from an original URL
    public fun create_short_link(
        owner: &signer, 
        original_url: String
    ): String acquires LinkRegistry {
        let owner_address = signer::address_of(owner);
        
        // Initialize registry if it doesn't exist
        if (!exists<LinkRegistry>(owner_address)) {
            let registry = LinkRegistry {
                links: table::new(),
                counter: 0,
            };
            move_to(owner, registry);
        };

        // Get mutable reference to registry
        let registry = borrow_global_mut<LinkRegistry>(owner_address);
        
        // Generate short ID using counter
        registry.counter = registry.counter + 1;
        let short_id = string::utf8(b"link_");
        string::append(&mut short_id, string::utf8(std::bcs::to_bytes(&registry.counter)));
        
        // Store the mapping
        table::add(&mut registry.links, short_id, original_url);
        
        short_id
    }

    /// Function to retrieve the original URL from a short link
    public fun get_original_url(
        registry_owner: address, 
        short_id: String
    ): String acquires LinkRegistry {
        // Check if registry exists
        assert!(exists<LinkRegistry>(registry_owner), E_REGISTRY_NOT_FOUND);
        
        let registry = borrow_global<LinkRegistry>(registry_owner);
        
        // Check if short link exists
        assert!(table::contains(&registry.links, short_id), E_LINK_NOT_FOUND);
        
        *table::borrow(&registry.links, short_id)
    }
}