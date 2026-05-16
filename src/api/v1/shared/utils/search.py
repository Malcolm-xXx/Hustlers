import re


def build_prefix_tsquery(value: str) -> str | None:
    terms = [re.sub(r"[^\w]+", "", part).lower() for part in value.split()]
    normalized_terms = [term for term in terms if term]
    if not normalized_terms:
        return None
    return " & ".join(f"{term}:*" for term in normalized_terms)
