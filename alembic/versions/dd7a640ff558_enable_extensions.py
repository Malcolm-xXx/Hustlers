"""enable extensions

Revision ID: dd7a640ff558
Revises: a31e6b769de5
Create Date: 2026-04-29 07:58:43.326574

"""

from typing import Sequence, Union

from alembic import op
from sqlalchemy import text


# revision identifiers, used by Alembic.
revision: str = "dd7a640ff558"
down_revision: Union[str, Sequence[str], None] = "a31e6b769de5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.execute(text('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'))
    op.execute(text("CREATE EXTENSION IF NOT EXISTS pgcrypto"))
    op.execute(text("CREATE EXTENSION IF NOT EXISTS cube"))
    op.execute(text("CREATE EXTENSION IF NOT EXISTS earthdistance"))


def downgrade() -> None:
    """Downgrade schema."""
    op.execute(text("DROP EXTENSION IF EXISTS earthdistance"))
    op.execute(text("DROP EXTENSION IF EXISTS cube"))
    op.execute(text("DROP EXTENSION IF EXISTS pgcrypto"))
    op.execute(text('DROP EXTENSION IF EXISTS "uuid-ossp"'))
