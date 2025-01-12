CLIENT :: true;
SERVER :: true;

#if CLIENT #load "client.p";

main :: () -> s32 {
    #if CLIENT client_entry_point();
    return 0;
}