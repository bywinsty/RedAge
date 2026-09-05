let editionReported = false;

const reportEdition = () => {
    if (editionReported) return;
    editionReported = true;

    try {
        const gameplay = mp && mp.game && mp.game.gameplay;
        const isGen9 = Boolean(gameplay && gameplay.isGen9 === true);
        const edition = isGen9 ? 'Enhanced (Gen9)' : 'Legacy (Gen8)';
        const message = `RedAge client edition: ${edition}`;

        if (mp.console && typeof mp.console.logInfo === 'function') {
            mp.console.logInfo(message, true);
        } else if (typeof console !== 'undefined' && typeof console.log === 'function') {
            console.log(message);
        }
    } catch (error) {
        if (typeof console !== 'undefined' && typeof console.warn === 'function') {
            console.warn('[RedAge] Unable to detect client edition', error);
        }
    }
};

mp.events.add('playerReady', reportEdition);
