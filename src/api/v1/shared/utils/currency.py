"""Currency and number formatting utilities."""

from decimal import ROUND_HALF_UP, Decimal

_TWO_PLACES = Decimal("0.01")


def format_decimal(value: Decimal) -> str:
    """Format Decimal to 2 decimal places using default rounding."""
    return format(value.quantize(_TWO_PLACES), "f")


def format_money(value: Decimal) -> str:
    """Format Decimal to 2 decimal places using ROUND_HALF_UP."""
    return format(value.quantize(_TWO_PLACES, rounding=ROUND_HALF_UP), "f")
