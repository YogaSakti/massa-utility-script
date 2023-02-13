#!/bin/bash
DELAY=3600 #in secs - how often restart the script
ROLL_PRICE=100
BOT_TOKEN=
CHAT_ID=
PASSWD=

for (( ; ; )); do
        WALLET_INFO=$(massa-client -j wallet_info -p $PASSWD | jq .)
        ADDRESS=$(jq -r 'keys[]' <<<$WALLET_INFO)

        WALLET_DETAIL=$(jq -r '. | keys[] as $k | "\(.[$k] | .address_info)"' <<<$WALLET_INFO)
        FINAL_BAL=$(jq -r '.final_balance' <<<$WALLET_DETAIL)
        CANDIDATE_BAL=$(jq -r '.candidate_balance' <<<$WALLET_DETAIL)

        ROLLS=$(jq -r '. | keys[] as $k | "\(.[$k] | .address_info)"' <<<$WALLET_INFO)
        FINAL_ROLL=$(jq -r '.final_rolls' <<<$ROLLS)
        CANDIDATE_ROLL=$(jq -r '.candidate_rolls' <<<$ROLLS)
        ACTIVE_ROLL=$(jq -r '.active_rolls' <<<$ROLLS)

        BUYABLE_ROLL=$(bc -l <<<"scale=0; $FINAL_BAL/$ROLL_PRICE")
        

        echo -e "================================ Massa Node ================================"
        echo -e "[>] Address: ${ADDRESS}"
        echo -e "================================= Balances ================================="
        echo -e "[>] Final Balance: ${FINAL_BAL}"
        echo -e "[>] Candidate Balance: ${CANDIDATE_BAL}"
        echo -e "================================== Rolls ==================================="
        echo -e "[>] Final Roll: ${FINAL_ROLL}"
        echo -e "[>] Candidate Roll: ${CANDIDATE_ROLL}"
        echo -e "[>] Active Roll: ${ACTIVE_ROLL}"


        if [ "$BUYABLE_ROLL" -gt 0 ]; then
                echo -e "================================= Success ================================="
                echo -e "[+] Balance : ${FINAL_BAL}"
                echo -e "[+] Buyable : ${BUYABLE_ROLL}"
                CMD_BUY_ROLL=$(massa-client buy_rolls $ADDRESS $BUYABLE_ROLL 0 -j -p $PASSWD| jq -r '.[]')
                echo -e "[+] Tx Hash : ${CMD_BUY_ROLL}"
                curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage -d parse_mode=HTML -d chat_id=$CHAT_ID -d disable_web_page_preview=True -d text="============ Massa ============%0A[>] Address: <a href=\"https://test.massa.net/#explorer?explore=${ADDRESS}\">${ADDRESS}</a>%0A================ Balance %0A[$] Final: ${FINAL_BAL}%0A[$] Candidate: ${CANDIDATE_BAL}%0A================ Rolls %0A[#] Final: ${FINAL_ROLL}%0A[#] Candidate: ${CANDIDATE_ROLL}%0A[#] Active: ${ACTIVE_ROLL}%0A================ Success! %0A[!!] Used: ${FINAL_BAL}%0A[!!] Buy: ${BUYABLE_ROLL}%0A[!!] Tx: <a href=\"https://test.massa.net/#explorer?explore=${CMD_BUY_ROLL}\">${CMD_BUY_ROLL}</a>%0A=============================="
        else
                echo -e "================================= Failed! =================================="
                echo -e "[x] You don't have enough coins to buy roll"
                #     curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage -d parse_mode=HTML -d chat_id=$CHAT_ID -d text="=================== Massa Node ===================%0A[>] Address: ${ADDRESS}%0A==================== Balances =====================%0A[>] Final: ${FINAL_BAL}%0A[>] Candidate: ${CANDIDATE_BAL}%0A[>] Locked: ${LOCKED_BAL}%0A====================== Rolls ======================%0A[>] Final: ${FINAL_ROLL}%0A[>] Candidate: ${CANDIDATE_ROLL}%0A[>] Active: ${ACTIVE_ROLL}%0A================================================="
        fi
        echo -e "================================== Delay! =================================="
        for ((timer = ${DELAY}; timer >= 0; timer--)); do
                printf "[+] Sleep for ${RED}%02d${NC} sec\r" $timer
                sleep 1
        done
        echo -e "\n============================================================================"
done

