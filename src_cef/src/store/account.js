import { writable } from 'svelte/store';

window.accountStore = {};

// Хранилище содержит данные аккаунта после успешной авторизации.
// До этого оно пустое; данные передаются сервером через обработчик авторизации ниже.
const createEmptyAccountData = () => ({
    Login: "",
    SocialClub: "",
    Redbucks: 0,
    Vip: 0,
    VipDate: "",
    Unique: "",
    LastSelectCharUUID: -1,
    Subscribe: false,
    Email: "",
    Ga: "",
    charsSlot: [],
    chars: {},
});

const normalizeAccountData = (value) => {
    const data = value && typeof value === "object" && !Array.isArray(value)
        ? value
        : {};

    return {
        ...createEmptyAccountData(),
        ...data,
        charsSlot: Array.isArray(data.charsSlot) ? data.charsSlot : [],
        chars: data.chars && typeof data.chars === "object" && !Array.isArray(data.chars)
            ? data.chars
            : {},
    };
};

export const accountData = writable(createEmptyAccountData());
window.accountStore.accountData = (value) => {
    try {
        accountData.set(normalizeAccountData(JSON.parse(value)));
    } catch (error) {
        console.error("Unable to load account data", error);
        accountData.set(createEmptyAccountData());
    }
}

let localAccountData = createEmptyAccountData();
accountData.subscribe(value => {
	localAccountData = value;
}); 

window.accountStore.unlockSlots = (slotId) => {
    localAccountData.charsSlot[slotId] = -1;
    accountData.set(localAccountData);
}

window.accountStore.deleteCharacter = (slot, data) => {
    const uuid = localAccountData.charsSlot[slot];
    localAccountData.chars[uuid].Data.DeleteData = data;
    accountData.set(localAccountData);
}

window.accountStore.deleteSuccessCharacter = (slot) => {
    const uuid = localAccountData.charsSlot[slot];
    localAccountData.charsSlot[slot] = -1;
    localAccountData.chars[uuid] = null;
    delete localAccountData.chars[uuid];
    accountData.set(localAccountData);
}

///

export const otherStatsData = writable({});
window.accountStore.otherStatsData = (json) => otherStatsData.set (JSON.parse (json));

export const accountRedbucks = writable(0);
window.accountStore.accountRedbucks = (value) => accountRedbucks.set (value);

export const accountUnique = writable("");
window.accountStore.accountUnique = (value) => accountUnique.set (value);

export const accountVip = writable(0);
window.accountStore.accountVip = (value) => accountVip.set (value);

export const accountVipDate = writable("2021-05-29T22:16:04");
window.accountStore.accountVipDate = (value) => accountVipDate.set (value);

export const accountSubscribe = writable("false");
window.accountStore.accountSubscribe = (value) => accountSubscribe.set (value);

//
export const accountLogin = writable(-99);
window.accountStore.accountLogin = (value) => accountLogin.set (value);

export const accountSocialClub = writable(0);
window.accountStore.accountSocialClub = (value) => accountSocialClub.set (value);

export const accountSelectCharId = writable(0);
window.accountStore.accountSelectCharId = (value) => accountSelectCharId.set (value);

export const accountIsSession = writable(0);
window.accountStore.accountIsSession = (value) => accountIsSession.set (value);

export const accountEmail = writable("");
window.accountStore.accountEmail = (value) => accountEmail.set (value);

