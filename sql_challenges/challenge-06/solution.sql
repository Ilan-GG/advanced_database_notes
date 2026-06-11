CREATE OR REPLACE TRIGGER trg_pet_care_log_bi
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    :NEW.UPDATE_DATE := SYSDATE;
    :NEW.UPDATED_BY_USER := USER;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Error inserting PET_CARE_LOG record: ' || SQLERRM
        );
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_bu
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF USER <> :OLD.UPDATED_BY_USER THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'You may only update records that you created.'
        );
    END IF;

    :NEW.UPDATE_DATE := SYSDATE;
    :NEW.UPDATED_BY_USER := USER;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'Error updating PET_CARE_LOG record: ' || SQLERRM
            );
        ELSE
            RAISE;
        END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_bd
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF UPPER(USER) <> 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Only JOEMANAGER may delete records from PET_CARE_LOG.'
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            RAISE_APPLICATION_ERROR(
                -20005,
                'Error deleting PET_CARE_LOG record: ' || SQLERRM
            );
        ELSE
            RAISE;
        END IF;
END;
/