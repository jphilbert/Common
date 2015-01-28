) AS localUrl,
    OtherDF.hash,
    OtherDF.remoteUrl,
    OtherDF.unlinked,
    OtherDF.downloadRestricted
FROM MatchId as M
    INNER JOIN
    mendeley.DocumentFiles as OtherDF ON
    OtherDF.documentId = M.otherDocumentID
    INNER JOIN
    mendeley.Files OtherF ON OtherDF.hash=OtherF.hash
WHERE (OtherF.localUrl IS NOT NULL)
    ;

INSERT OR REPLACE INTO Files (hash, localUrl)
SELECT
    DISTINCT hash,
    localUrl
FROM
    NewData;

INSERT INTO DocumentFiles (documentId,
	hash,
	remoteUrl,
	unlinked,
	downloadRestricted)
SELECT DISTINCT
    documentId,
    hash,
    remoteUrl,
    unlinked,
    downloadRestricted
FROM
    NewData as U
WHERE NOT EXISTS (
    select
	*
    from
	DocumentFiles as DF
    where
	U.documentId = DF.documentID AND U.hash = DF.hash);

DROP TABLE NewData;
DROP TABLE MatchId;
    COMMIT;

    