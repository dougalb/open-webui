"""rename_tables_to_plural

Revision ID: 71a383a187d4
Revises: 9f0c9cd09105
Create Date: 2025-06-21 16:32:53.556363

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import open_webui.internal.db


# revision identifiers, used by Alembic.
revision: str = '71a383a187d4'
down_revision: Union[str, None] = '9f0c9cd09105'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Renaming tables
    op.rename_table('user', 'users')
    op.rename_table('group', 'groups')
    op.rename_table('file', 'files')
    op.rename_table('function', 'functions')


def downgrade() -> None:
    pass
