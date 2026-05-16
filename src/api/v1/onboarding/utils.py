def serialize_default_address(address) -> dict[str, object]:
    return {
        "id": str(address.id),
        "location": {
            "id": str(address.id),
            "name": address.name,
            "address_text": address.address_text,
            "coordinates": {
                "latitude": address.latitude,
                "longitude": address.longitude,
            },
        },
        "is_default": address.is_default,
        "created_at": address.created_at,
    }
