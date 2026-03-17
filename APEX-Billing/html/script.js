var payeffect = new Audio(`./sounds/pay.mp3`);

$(document).keydown(function (e) {
    if (e.key === 'Escape') {
        $.post('https://' + GetParentResourceName() + '/closeDisplay', JSON.stringify({}));
        $('.box-center-bill').hide();
    }
})

$(document).ready(function () {
    payeffect.volume = 0.1;
    $('.btn-bill').click(function () {
        $('.btn-bill').css('background', 'var(--color-base)'); 
        $('.btn-history').css('background', 'var(--menu-bg)'); 
        ExtractBills(0);
    });
    $('.btn-history').click(function () {
        $('.btn-history').css('background', 'var(--color-base)'); 
        $('.btn-bill').css('background', 'var(--menu-bg)'); 
        ExtractBills(1);
    });
});


window.addEventListener('message', function ({ data }) {
    switch (data.action) {
        case 'mybill':
            $('.box-center-bill').show();
            $('.tables-bill').html(`<thead>
            <tr>
                <th scope="col" class="first-col">บิล</th>
                <th scope="col">ค่าปรับ</th>
                <th scope="col">รับเมื่อ</th>
                <th scope="col">หน่วยงาน</th>
                <th scope="col"  class="last-col">จัดการ</th>
            </tr>
        </thead><tbody></tbody>`);
            Bills = data.bills;
            $('.btn-bill').css('background', 'var(--color-base)'); 
            $('.btn-history').css('background', 'var(--menu-bg)'); 
            ExtractBills(0);
            break
        case 'play':
            payeffect.play();
            break
    };
});

DepartMentLabel = function (name) {
    if (name == 'police') {
        return 'ตำรวจ';
    };
    if (name == 'ambulance') {
        return 'แพทย์';
    };
    if (name == 'council') {
        return 'TEST SUPPORT';
    };
};

Pay = function (id) {
    $.each(Bills, function (i, v) {
        if (v.id == id) {
            Bills[i].pay = 1;
            Bills[i].pay_time = getCurrentDateTime();
        };
    });
};

function getCurrentDateTime() {
    let now = new Date();
    let year = now.getFullYear();
    let month = String(now.getMonth() + 1).padStart(2, '0');
    let day = String(now.getDate()).padStart(2, '0');
    let hours = String(now.getHours()).padStart(2, '0');
    let minutes = String(now.getMinutes()).padStart(2, '0');
    let seconds = String(now.getSeconds()).padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
};

ExtractBills = function (history) {
    if (history == 0) {
        $('.listbill').html(`<table class="tables-bill">
        <thead>
            <tr>
                <th scope="col" class="first-col">บิล</th>
                <th scope="col">จำนวน</th>
                <th scope="col">รับเมื่อ</th>
                <th scope="col">หน่วยงาน</th>
                <th scope="col" class="last-col">ชำระ</th>
            </tr>
        </thead>
        <tbody></tbody>
        </table>`)
        $.each(Bills, function (i, v) {
            if (v.pay == 0) {
                const tr = `<tr id = "bill-id-${v.id}">
                    <td scope="row" >${v.reason}</td>
                    <td>$${v.amount.toLocaleString()}</td>
                    <td >${v.date}</td>
                    <td >${DepartMentLabel(v.senderjob)}</td>
                    <td>
                        <img id="bill-${i}" class="Bill-acion-icon" src="./img/wallet.png" alt="" width="28">
                    </td>
                </tr>`;
                $(".tables-bill tbody").append(tr);
                $(".tables-bill td[scope='row']").each(function () {
                    const maxLength = 12;
                    const fullText = $(this).text().trim();

                    if (fullText.length > maxLength) {
                        const shortText = fullText.substring(0, maxLength) + "...";
                        $(this).html(`<span class="custom-tooltip" data-tooltip="${fullText}">${shortText}</span>`);
                    }
                });
                $(`#bill-${i}`).click(function () {
                    $.post('https://' + GetParentResourceName() + '/paybill', JSON.stringify({
                        billid: v.id,
                    }), function (cb) {
                        if (cb) {
                            payeffect.play();
                            $(`#bill-id-${v.id}`).remove();
                            Pay(v.id)
                        }
                    })
                })
            };
        });
    } else {
        $('.listbill').html(`<table class="tables-bill">
        <thead>
            <tr>
                <th scope="col" class="first-col">บิล</th>
                <th scope="col">จำนวน</th>
                <th scope="col">ชำระเมื่อ</th>
                <th scope="col">หน่วยงาน</th> 
            </tr>
        </thead>
        <tbody></tbody>
        </table>`);
        $.each(Bills, function (i, v) {
            if (v.pay == 1) {
                const tr = `<tr id = "bill-id-${v.id}">
                <td scope="row">${v.reason}</td>
                <td >$${v.amount.toLocaleString()}</td>
                <td >${v.pay_time || 'ไม่ทราบเวลา'}</td>
                <td >${DepartMentLabel(v.senderjob)}</td> 
                </tr>`;
                $(".tables-bill tbody").append(tr);
                $(".tables-bill td[scope='row']").each(function () {
                    const maxLength = 12;
                    const fullText = $(this).text().trim();

                    if (fullText.length > maxLength) {
                        const shortText = fullText.substring(0, maxLength) + "...";
                        $(this).html(`<span class="custom-tooltip" data-tooltip="${fullText}">${shortText}</span>`);
                    }
                });
                $(`#bill-${i}`).click(function () {
                    $(`#bill-id-${v.id}`).remove();
                    $.post('https://' + GetParentResourceName() + '/deletebill', JSON.stringify({
                        billid: v.id,
                    }));
                })
            };
        });
    };
};