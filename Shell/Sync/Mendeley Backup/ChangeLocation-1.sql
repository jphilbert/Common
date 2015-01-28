ATTACH DATABASE 'db.sqlite' as mendeley;

BEGIN IMMEDIATE TRANSACTION;

CREATE TEMPORARY TABLE MatchId AS
SELECT
    D.uuid as uuid,
    d.id as documentId,
    otherD.id as otherDocumentID
from
    Documents as D
    INNER JOIN mendeley.Documents as OtherD ON (D.uuid=OtherD.uuid);

CREATE TEMPORARY TABLE NewData AS
SELECT
    M.documentId as documentId,
    replace(lower(OtherF.localUrl),