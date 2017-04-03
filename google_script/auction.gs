// REGEXES will fail to recognize "200x" prefixes.

// constants
COL_DONOR            = 1;
COL_TICKET_VALUE     = 2;
COL_PURCHASE_AMOUNT  = 3;
COL_BUYER            = 4;
COL_STATUS           = 5;
COL_ITEMS            = 6;
COL_LINKS            = 7;
COL_CT               = 7;

                // 6 or more item links in a single chat message can
                // sometimes chop off part of the 6th item link.
MAX_ROW_LINK_CT      = 5;

// If the frontmost sheet is not the "Auction" sheet, do nothing.
function ThrowIfNotAuctionSheet()
{
 var sheet = SpreadsheetApp.getActiveSheet()
 if (sheet.getName() != "Auction")
 {
   var msg = 'Only works on "Auction" sheet.'
   throw msg;
 }
}

// Split a single "Donated by @name  link1 link2 link3..." into an
// array of ["Donated by @name link1", "Donated by @name link2",
// "Donated by @name link3", ... ]

function SplitLinkText(link_text)
{
  var re_donate_links = /Donated by (@[^ :]+)/i;
  var t = re_donate_links.exec(link_text)
  var donor_name = t[1];

                // Split out the (usually multiple) links.
                // Note that split() here includes TWO elements per capture:
                // - the capture itself (what we want)
                // - the stuff before or after the capture (empty string we ignore)
                // So filter that out.
  var re_one_link     = / *([\dx]*\|H\d:item:[\d:]+\|h\|h) */;
  var split_link_arr  = link_text.split(re_one_link);
  var link_arr        = []
  for (var i = 1; i <= split_link_arr.length; ++i)
  {
    if (split_link_arr[i])
    {
      link_arr.push(split_link_arr[i])
    }
  }

  return { donor_name : donor_name
         , link_arr   : link_arr
         }
}

// Return the donor and item links from a single row.
function DonorLinkArr(row_index)
{
  var sheet      = SpreadsheetApp.getActiveSheet();
  var col_index  = COL_LINKS;
  var link_range = sheet.getRange(row_index, col_index);
  var link_text  = link_range.getDisplayValue();
  return SplitLinkText(link_text);
}

function InsertAndCopyRows(row_index, row_insert_ct)
{
            // Make a hole
  var sheet      = SpreadsheetApp.getActiveSheet();
  sheet.insertRowsAfter(row_index, row_insert_ct);

            // Duplicate original row to all new rows.
  var copy_range  = sheet.getRange(row_index,  1, 1, COL_CT);
  var paste_range = sheet.getRange(row_index + 1, 1, row_insert_ct, COL_CT);
  copy_range.copyTo(paste_range)
}

function DeleteRows(row_index, row_delete_ct)
{
  var sheet      = SpreadsheetApp.getActiveSheet();
  sheet.deleteRows(row_index, row_delete_ct)
}

// Split a single row into multiple, one for each link in its COL_LINKS text.
function SplitRow(row_index)
{
  var sheet      = SpreadsheetApp.getActiveSheet();
  var dl         = DonorLinkArr(row_index)
  var link_arr   = dl.link_arr
  if (link_arr.length <= 1)
  {
    throw "Only one item. Nothing to split."
  }

  var row_insert_ct = dl.link_arr.length - 1
  InsertAndCopyRows(row_index, row_insert_ct)

            // Split the item links across the original+new rows.
  for (var i = 0; i <= row_insert_ct; ++i)
  {
      var cell_range = sheet.getRange(row_index + i, COL_LINKS)
      cell_range.setValue("Donated by " + dl.donor_name + ": " + link_arr[i])
  }
}

// I don't know why array.concat() doesn't do anything, but it doesn't
// and I have higher level things to do than to solve that right now.
function ArrayCat(t1, t2)
{
  for (var i = 0; i < t2.length; ++i)
  {
    t1.push(t2[i])
  }
}

function MergedDonorLinkArr(row_index, row_ct)
{
            // Build a single, long, array of all the links we're merging.
            // While doing so, check that all the donors match.
  var merged_dl = { donor_name : null
                  , link_arr   : []
                  }
  for (var i = 0; i < row_ct; ++i)
  {
    var dl = DonorLinkArr(row_index + i) ;
    if (!merged_dl.donor_name)
    {
      merged_dl.donor_name = dl.donor_name
    }
    else if (merged_dl.donor_name != dl.donor_name)
    {
      throw "Can only merge rows from a single donor.";
    }
    ArrayCat(merged_dl.link_arr, dl.link_arr);
  }
  return merged_dl;
}

// Merge two or more adjacent rows into as few rows as possible.
// The result might have more than one row if there are more item links
// than can fit on a single chat line.
function MergeRows(row_index, row_ct)
{
  var sheet     = SpreadsheetApp.getActiveSheet();
  var merged_dl = MergedDonorLinkArr(row_index, row_ct)

  var need_row_ct = Math.ceil(merged_dl.link_arr.length / MAX_ROW_LINK_CT)

          // Get rid of excess rows.
  if (need_row_ct < row_ct)
  {
    DeleteRows(row_index + 1, row_ct - need_row_ct)
  }
          // Somehow you have too few rows and need MORE? Could happen
          // if you manually copied-and-pasted to create rows with more
          // than MAX_ROW_LINK_CT links.
  else if(row_ct < need_row_ct)
  {
   InsertAndCopyRows(row_index, need_row_ct - row_ct)
  }

          // Reflow links across rows
  for (var row_i = 0; row_i < need_row_ct; ++row_i)
  {
    var txt = MergeLinkText(merged_dl.link_arr
                              , row_i * MAX_ROW_LINK_CT, MAX_ROW_LINK_CT)
    var cell_range = sheet.getRange(row_index + row_i, COL_LINKS)
    cell_range.setValue("Donated by " + merged_dl.donor_name + ":" + txt)
  }
}

// Merge up to link_ct links from start_link_index.
// OK to ask for more elements than link_arr contains. Stops at the end of link_arr.
function MergeLinkText(link_arr, start_link_index, link_ct)
{
  var txt = ""
  for (var i = 0; i < link_ct && (start_link_index + i) < link_arr.length; ++i)
  {
    txt = txt + " " + link_arr[start_link_index + i]
  }
  return txt
}

// -- UI ------------------------------------------------------
function onOpen()
{
  var spreadsheet = SpreadsheetApp.getActive();
  var menu_items = [ { name: 'Split Row'
                     , functionName: 'UISplitRows'
                     }
                   , { name: 'Merge Rows'
                     , functionName: 'UIMergeRows'
                     }
                   ];
  spreadsheet.addMenu('ZZ', menu_items);
}

function UISplitRows()
{
  ThrowIfNotAuctionSheet();
  var sheet      = SpreadsheetApp.getActiveSheet();
  var sel_range  = sheet.getActiveRange();
  if (1 != sel_range.getNumRows()) throw "Can split only single rows." ;
  var row_index  = sel_range.getRowIndex();
  SplitRow(row_index)
}

function UIMergeRows()
{
  ThrowIfNotAuctionSheet()
  var sheet      = SpreadsheetApp.getActiveSheet();
  var sel_range  = sheet.getActiveRange();
  if (sel_range.getNumRows() <= 1) throw "Can merge only two or more rows." ;
  var row_index  = sel_range.getRowIndex();
  MergeRows(row_index, sel_range.getNumRows())
}

