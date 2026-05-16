from email.message import EmailMessage

import aiosmtplib
import resend

from src.core.config import settings
from src.core.logging import get_logger

logger = get_logger(__name__)


async def send_email(
    to: str | list[str],
    subject: str,
    html: str | None = None,
    text: str | None = None,
) -> dict:
    """
    Send an email using the configured provider.

    In DEBUG mode, prints email content to console instead of sending.

    Args:
        to: Recipient email address(es)
        subject: Email subject line
        html: HTML body content
        text: Plain text body content (fallback if html not provided)

    Returns:
        dict with 'id' key on success, 'mock' key in DEBUG mode
    """
    if isinstance(to, list):
        to_list = to
    else:
        to_list = [to]

    from_email = settings.DEFAULT_FROM_EMAIL or settings.SMTP_USER

    # In DEBUG mode, print to console instead of sending
    if settings.DEBUG:
        return await debug_send_email(to_list, subject, html, text, from_email)

    match settings.EMAIL_PROVIDER:
        case "smtp":
            return await send_smtp(to_list, subject, html, text, from_email)
        case _:
            return await send_resend(to_list, subject, html, text, from_email)


async def debug_send_email(
    to_list: list[str],
    subject: str,
    html: str | None,
    text: str | None,
    from_email: str,
) -> dict:
    """Print email to console in DEBUG mode."""
    body = html or text or "(empty)"
    logger.info("=" * 50)
    logger.info("DEBUG EMAIL - Would send:")
    logger.info(f"  From: {from_email}")
    logger.info(f"  To: {', '.join(to_list)}")
    logger.info(f"  Subject: {subject}")
    logger.info(f"  Body: {body[:200]}...")
    logger.info("=" * 50)
    return {"id": "debug_mock", "mock": True}


async def send_resend(
    to_list: list[str],
    subject: str,
    html: str | None,
    text: str | None,
    from_email: str,
) -> dict:
    """Send email via Resend API."""
    if not settings.RESEND_API_KEY:
        raise ValueError("RESEND_API_KEY not configured")

    resend.api_key = settings.RESEND_API_KEY

    params: resend.Emails.SendParams = {
        "from": from_email,
        "to": to_list,
        "subject": subject,
    }

    if html:
        params["html"] = html
    elif text:
        params["html"] = f"<pre>{text}</pre>"

    result = await resend.Emails.send_async(params)
    return dict(result)  # type: ignore[arg-type]


async def send_smtp(
    to_list: list[str],
    subject: str,
    html: str | None,
    text: str | None,
    from_email: str,
) -> dict:
    """Send email via Gmail SMTP using aiosmtplib."""
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        raise ValueError("SMTP_USER and SMTP_PASSWORD not configured")

    message = EmailMessage()
    message["From"] = from_email
    message["To"] = ", ".join(to_list)
    message["Subject"] = subject

    if html:
        message.set_content(html, subtype="html")
    elif text:
        message.set_content(text)
    else:
        message.set_content("(empty)")

    await aiosmtplib.send(
        message,
        hostname=settings.SMTP_HOST,
        port=settings.SMTP_PORT,
        username=settings.SMTP_USER,
        password=settings.SMTP_PASSWORD,
        use_tls=True,
    )

    return {"id": "smtp_sent", "from": from_email, "to": to_list}
